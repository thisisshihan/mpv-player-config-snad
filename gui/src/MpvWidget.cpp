#include "MpvWidget.h"
#include <QKeyEvent>
#include <QMouseEvent>
#include <QOpenGLContext>
#include <QWheelEvent>
#include <QByteArray>
#include <vector>

static void *getProcAddress(void *, const char *name)
{
    auto *ctx = QOpenGLContext::currentContext();
    return ctx ? reinterpret_cast<void *>(ctx->getProcAddress(name)) : nullptr;
}

MpvWidget::MpvWidget(const QString &configDir, QWidget *parent) : QOpenGLWidget(parent)
{
    setMouseTracking(true);
    setFocusPolicy(Qt::StrongFocus);

    mpv_ = mpv_create();
    // Load the repo's mpv.conf / input.conf / scripts exactly as the stock player would.
    mpv_set_option_string(mpv_, "config", "yes");
    mpv_set_option_string(mpv_, "config-dir", configDir.toUtf8().constData());
    mpv_set_option_string(mpv_, "osc", "yes");
    mpv_set_option_string(mpv_, "input-default-bindings", "yes");
    mpv_set_option_string(mpv_, "input-vo-keyboard", "yes");
    mpv_set_option_string(mpv_, "load-scripts", "yes");
    mpv_set_option_string(mpv_, "vo", "libmpv");
    mpv_initialize(mpv_);

    mpv_set_wakeup_callback(mpv_, [](void *ctx) {
        QMetaObject::invokeMethod(static_cast<MpvWidget *>(ctx), "drainEvents", Qt::QueuedConnection);
    }, this);
}

MpvWidget::~MpvWidget()
{
    makeCurrent();
    if (render_) mpv_render_context_free(render_);
    mpv_terminate_destroy(mpv_);
}

void MpvWidget::initializeGL()
{
    mpv_opengl_init_params gl{getProcAddress, nullptr};
    int advanced = 1;
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
        {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl},
        {MPV_RENDER_PARAM_ADVANCED_CONTROL, &advanced},
        {MPV_RENDER_PARAM_INVALID, nullptr}};
    mpv_render_context_create(&render_, mpv_, params);
    mpv_render_context_set_update_callback(render_, [](void *ctx) {
        QMetaObject::invokeMethod(static_cast<MpvWidget *>(ctx), "update", Qt::QueuedConnection);
    }, this);
}

void MpvWidget::paintGL()
{
    qreal dpr = devicePixelRatioF();
    mpv_opengl_fbo fbo{static_cast<int>(defaultFramebufferObject()),
                       static_cast<int>(width() * dpr), static_cast<int>(height() * dpr), 0};
    int flip = 1;
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
        {MPV_RENDER_PARAM_FLIP_Y, &flip},
        {MPV_RENDER_PARAM_INVALID, nullptr}};
    mpv_render_context_render(render_, params);
}

void MpvWidget::drainEvents()
{
    while (mpv_event *ev = mpv_wait_event(mpv_, 0)) {
        if (ev->event_id == MPV_EVENT_NONE) break;
        emit mpvEvent();
    }
}

void MpvWidget::command(const QStringList &args)
{
    std::vector<QByteArray> bytes;
    for (const QString &a : args) bytes.push_back(a.toUtf8());
    std::vector<const char *> argv;
    for (auto &b : bytes) argv.push_back(b.constData());
    argv.push_back(nullptr);
    mpv_command_async(mpv_, 0, argv.data());
}

void MpvWidget::setProperty(const QString &name, const QString &value)
{
    mpv_set_property_string(mpv_, name.toUtf8().constData(), value.toUtf8().constData());
}

void MpvWidget::loadFile(const QString &path) { command({"loadfile", path}); }

QString MpvWidget::keyName(QKeyEvent *e)
{
    switch (e->key()) {
    case Qt::Key_Space: return "SPACE";
    case Qt::Key_Left: return "LEFT";
    case Qt::Key_Right: return "RIGHT";
    case Qt::Key_Up: return "UP";
    case Qt::Key_Down: return "DOWN";
    case Qt::Key_Return: case Qt::Key_Enter: return "ENTER";
    case Qt::Key_Escape: return "ESC";
    case Qt::Key_Tab: return "TAB";
    case Qt::Key_Backspace: return "BS";
    case Qt::Key_Home: return "HOME";
    case Qt::Key_End: return "END";
    case Qt::Key_PageUp: return "PGUP";
    case Qt::Key_PageDown: return "PGDWN";
    case Qt::Key_Delete: return "DEL";
    case Qt::Key_Insert: return "INS";
    default: break;
    }
    if (e->key() >= Qt::Key_F1 && e->key() <= Qt::Key_F12)
        return QString("F%1").arg(e->key() - Qt::Key_F1 + 1);
    QString t = e->text();
    QString name = (t.isEmpty() || !t[0].isPrint()) ? QString() : t;
    if (name.isEmpty() && e->key() < 0x7f)
        name = QString(QChar(e->key())).toLower();
    if (name.isEmpty()) return {};
    if (e->modifiers() & Qt::ControlModifier) name = "Ctrl+" + QString(QChar(e->key())).toLower();
    if (e->modifiers() & Qt::AltModifier) name = "Alt+" + name;
    return name;
}

void MpvWidget::keyPressEvent(QKeyEvent *e)
{
    QString n = keyName(e);
    if (n.isEmpty()) { QOpenGLWidget::keyPressEvent(e); return; }
    command({e->isAutoRepeat() ? "keypress" : "keydown", n});
    if (e->isAutoRepeat()) return;
}

void MpvWidget::keyReleaseEvent(QKeyEvent *e)
{
    QString n = keyName(e);
    if (n.isEmpty() || e->isAutoRepeat()) { QOpenGLWidget::keyReleaseEvent(e); return; }
    command({"keyup", n});
}

void MpvWidget::mouseMoveEvent(QMouseEvent *e)
{
    qreal d = devicePixelRatioF();
    command({"mouse", QString::number(int(e->position().x() * d)), QString::number(int(e->position().y() * d))});
}

static QString mouseButton(Qt::MouseButton b)
{
    switch (b) {
    case Qt::LeftButton: return "MBTN_LEFT";
    case Qt::RightButton: return "MBTN_RIGHT";
    case Qt::MiddleButton: return "MBTN_MID";
    case Qt::BackButton: return "MBTN_BACK";
    case Qt::ForwardButton: return "MBTN_FORWARD";
    default: return {};
    }
}

void MpvWidget::mousePressEvent(QMouseEvent *e)
{
    setFocus();
    QString b = mouseButton(e->button());
    if (!b.isEmpty()) command({"keydown", b});
}

void MpvWidget::mouseReleaseEvent(QMouseEvent *e)
{
    QString b = mouseButton(e->button());
    if (!b.isEmpty()) command({"keyup", b});
}

void MpvWidget::wheelEvent(QWheelEvent *e)
{
    if (e->angleDelta().y() > 0) command({"keypress", "WHEEL_UP"});
    else if (e->angleDelta().y() < 0) command({"keypress", "WHEEL_DOWN"});
}
