#pragma once
#include <QString>
#include <QStringList>

// Skins are Qt stylesheets (*.qss) in <portable_config>/skins, editable without a rebuild.
class SkinManager {
public:
    static QString skinsDir();
    static QStringList available();
    static bool apply(const QString &name);
};
