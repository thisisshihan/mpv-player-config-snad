#include "MainWindow.h"
#include "MpvWidget.h"
#include "SettingsDialog.h"
#include "SkinManager.h"
#include <QCoreApplication>
#include <QDragEnterEvent>
#include <QFileDialog>
#include <QInputDialog>
#include <QMenuBar>
#include <QMimeData>
#include <QSettings>

MainWindow::MainWindow()
{
    setWindowTitle("mpv.snad");
    resize(1280, 720);
    setAcceptDrops(true);

    mpv_ = new MpvWidget(QCoreApplication::applicationDirPath() + "/portable_config");
    setCentralWidget(mpv_);

    QMenu *file = menuBar()->addMenu("&File");
    file->addAction("&Open File...", this, [this] {
        QString f = QFileDialog::getOpenFileName(this, "Open media");
        if (!f.isEmpty()) mpv_->loadFile(f);
    }, QKeySequence::Open);
    file->addAction("Open &URL...", this, [this] {
        QString u = QInputDialog::getText(this, "Open URL", "URL:");
        if (!u.isEmpty()) mpv_->loadFile(u);
    });
    file->addSeparator();
    file->addAction("&Settings...", this, [this] {
        SettingsDialog dlg(this);
        connect(&dlg, &SettingsDialog::applied, this, &MainWindow::applySettings);
        dlg.exec();
    });
    file->addAction("E&xit", this, &QWidget::close, QKeySequence::Quit);

    applySettings();

    const QStringList args = QCoreApplication::arguments();
    if (args.size() > 1) mpv_->loadFile(args.at(1));
}

void MainWindow::applySettings()
{
    QSettings s(SettingsDialog::iniPath(), QSettings::IniFormat);
    SkinManager::apply(s.value("skin", "dark").toString());
    // Only override mpv.conf when the user picked a value in the GUI.
    QString hw = s.value("hwdec").toString();
    if (!hw.isEmpty()) mpv_->setProperty("hwdec", hw);
    mpv_->setProperty("volume", s.value("volume", 100).toString());
}

void MainWindow::dragEnterEvent(QDragEnterEvent *e)
{
    if (e->mimeData()->hasUrls()) e->acceptProposedAction();
}

void MainWindow::dropEvent(QDropEvent *e)
{
    for (const QUrl &u : e->mimeData()->urls())
        mpv_->command({"loadfile", u.isLocalFile() ? u.toLocalFile() : u.toString(), "append-play"});
}
