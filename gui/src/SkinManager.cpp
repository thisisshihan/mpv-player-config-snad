#include "SkinManager.h"
#include <QApplication>
#include <QDir>
#include <QFile>

QString SkinManager::skinsDir()
{
    return QCoreApplication::applicationDirPath() + "/portable_config/skins";
}

QStringList SkinManager::available()
{
    QStringList names;
    for (const QString &f : QDir(skinsDir()).entryList({"*.qss"}, QDir::Files))
        names << QFileInfo(f).completeBaseName();
    return names;
}

bool SkinManager::apply(const QString &name)
{
    QFile f(skinsDir() + "/" + name + ".qss");
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;
    qApp->setStyleSheet(QString::fromUtf8(f.readAll()));
    return true;
}
