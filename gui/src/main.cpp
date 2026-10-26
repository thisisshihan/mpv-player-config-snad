#include "MainWindow.h"
#include <QApplication>
#include <QSurfaceFormat>
#include <clocale>

int main(int argc, char **argv)
{
    QSurfaceFormat fmt;
    fmt.setVersion(3, 3);
    fmt.setProfile(QSurfaceFormat::CoreProfile);
    QSurfaceFormat::setDefaultFormat(fmt);

    QApplication app(argc, argv);
    std::setlocale(LC_NUMERIC, "C"); // libmpv requires the C numeric locale

    MainWindow w;
    w.show();
    return app.exec();
}
