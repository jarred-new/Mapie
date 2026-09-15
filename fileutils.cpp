#include "fileutils.h"

FileUtils::FileUtils(QObject *parent)
    : QObject{parent}
{}

QString FileUtils::getFileName(const QString &pathOrUrl) {
    QString strInfo = QFileInfo(pathOrUrl).fileName();
    return strInfo;
}