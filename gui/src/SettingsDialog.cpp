#include "SettingsDialog.h"
#include "SkinManager.h"
#include <QComboBox>
#include <QPushButton>
#include <QCoreApplication>
#include <QDialogButtonBox>
#include <QFormLayout>
#include <QSettings>
#include <QSpinBox>

QString SettingsDialog::iniPath()
{
    return QCoreApplication::applicationDirPath() + "/portable_config/gui-settings.ini";
}

SettingsDialog::SettingsDialog(QWidget *parent) : QDialog(parent)
{
    setWindowTitle("Settings");
    QSettings s(iniPath(), QSettings::IniFormat);

    skin_ = new QComboBox;
    skin_->addItems(SkinManager::available());
    skin_->setCurrentText(s.value("skin", "dark").toString());

    hwdec_ = new QComboBox;
    hwdec_->addItems({"", "auto-safe", "auto-copy", "d3d11va", "no"});
    hwdec_->setCurrentText(s.value("hwdec", "").toString());

    volume_ = new QSpinBox;
    volume_->setRange(0, 130);
    volume_->setValue(s.value("volume", 100).toInt());

    auto *form = new QFormLayout(this);
    form->addRow("Skin", skin_);
    form->addRow("Hardware decoding (empty = mpv.conf)", hwdec_);
    form->addRow("Startup volume", volume_);

    auto *box = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Apply | QDialogButtonBox::Cancel);
    form->addRow(box);
    connect(box, &QDialogButtonBox::accepted, this, [this] { save(); accept(); });
    connect(box->button(QDialogButtonBox::Apply), &QPushButton::clicked, this, &SettingsDialog::save);
    connect(box, &QDialogButtonBox::rejected, this, &QDialog::reject);
}

void SettingsDialog::save()
{
    QSettings s(iniPath(), QSettings::IniFormat);
    s.setValue("skin", skin_->currentText());
    s.setValue("hwdec", hwdec_->currentText());
    s.setValue("volume", volume_->value());
    emit applied();
}
