#pragma once
#include <QDialog>

class QComboBox;
class QSpinBox;

// GUI-level settings live in gui-settings.ini; mpv.conf from the repo is never rewritten.
class SettingsDialog : public QDialog {
    Q_OBJECT
public:
    explicit SettingsDialog(QWidget *parent = nullptr);
    static QString iniPath();

signals:
    void applied();

private:
    void save();
    QComboBox *skin_, *hwdec_;
    QSpinBox *volume_;
};
