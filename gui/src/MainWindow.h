#pragma once
#include <QMainWindow>

class MpvWidget;

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    MainWindow();

protected:
    void dragEnterEvent(QDragEnterEvent *e) override;
    void dropEvent(QDropEvent *e) override;

private:
    void applySettings();
    MpvWidget *mpv_;
};
