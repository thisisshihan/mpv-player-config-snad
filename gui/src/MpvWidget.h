#pragma once
#include <QOpenGLWidget>
#include <QStringList>
#include <mpv/client.h>
#include <mpv/render_gl.h>

class MpvWidget : public QOpenGLWidget {
    Q_OBJECT
public:
    explicit MpvWidget(const QString &configDir, QWidget *parent = nullptr);
    ~MpvWidget() override;

    void command(const QStringList &args);
    void setProperty(const QString &name, const QString &value);
    void loadFile(const QString &path);

signals:
    void mpvEvent();

protected:
    void initializeGL() override;
    void paintGL() override;
    void keyPressEvent(QKeyEvent *e) override;
    void keyReleaseEvent(QKeyEvent *e) override;
    void mouseMoveEvent(QMouseEvent *e) override;
    void mousePressEvent(QMouseEvent *e) override;
    void mouseReleaseEvent(QMouseEvent *e) override;
    void wheelEvent(QWheelEvent *e) override;

private slots:
    void drainEvents();

private:
    static QString keyName(QKeyEvent *e);
    mpv_handle *mpv_ = nullptr;
    mpv_render_context *render_ = nullptr;
};
