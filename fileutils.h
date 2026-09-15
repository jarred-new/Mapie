#ifndef FILEUTILS_H
#define FILEUTILS_H

#include <QObject>
#include <QFileInfo>

class FileUtils : public QObject
{
    Q_OBJECT
public:
    explicit FileUtils(QObject *parent = nullptr);

    Q_INVOKABLE QString getFileName(const QString &pathOrUrl);

signals:
};

#endif // FILEUTILS_H
