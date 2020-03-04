## Работа с лог файлом apache access_log

[Ссылка на лог файл](https://drive.google.com/open?id=1ZawA4XST_DMb5i9oGWeRet4yguvdHbYS)

##### 6.1. С каких ip-адресов были заходы

Команда: `cat access_log | cut -d' ' -f1 | sort | uniq`

Выполнение команды:

```ShellSession
bitnami@debian:/opt/bitnami/apache2/logs$ cat access_log | cut -d' ' -f1 | sort | uniq
192.168.41.2
192.168.41.249
192.168.41.5
```

##### 6.2. Были ли страницы 404? Если да, другой командой вывести битые страницы

- Проверка на 404, команда: `grep -w 404 access_log | sort`  
- Число ответов 404, команда: `grep -wc 404 access_log`  
- Вывод битых ресурсов, команда: `grep -w 404 access_log | cut -d' ' -f7 | sort | uniq`  
- Вывод запросов, команда: `grep -oP '(?<=").*(?=" 404)' access_log | sort | uniq`

Выполнение команд:

```ShellSession
bitnami@debian:/opt/bitnami/apache2/logs$ grep -w 404 access_log | sort
192.168.41.2 - - [04/Mar/2020:19:27:36 +0000] "GET /favicon.ico HTTP/1.1" 404 196
192.168.41.2 - - [04/Mar/2020:19:34:46 +0000] "GET /APP HTTP/1.1" 404 196
192.168.41.2 - - [04/Mar/2020:19:35:14 +0000] "GET /APP HTTP/1.1" 404 196
192.168.41.2 - - [04/Mar/2020:20:03:59 +0000] "GET /bitnami/css/normalize.css HTTP/1.1" 404 196
192.168.41.249 - - [04/Mar/2020:20:03:59 +0000] "GET /bitnami/css/normalize.css HTTP/1.1" 404 196
192.168.41.5 - - [04/Mar/2020:20:58:06 +0000] "GET /favicon.ico HTTP/1.1" 404 196
bitnami@debian:/opt/bitnami/apache2/logs$ grep -wc 404 access_log
6
bitnami@debian:/opt/bitnami/apache2/logs$ grep -w 404 access_log | cut -d' ' -f7 | sort | uniq
/APP
/bitnami/css/normalize.css
/favicon.ico
bitnami@debian:/opt/bitnami/apache2/logs$ grep -oP '(?<=").*(?=" 404)' access_log | sort | uniq
GET /APP HTTP/1.1
GET /bitnami/css/normalize.css HTTP/1.1
GET /favicon.ico HTTP/1.1
```

##### 6.3 Были ли ошибки сервера (коды ответа 50х), если да, вывести страницы

- Проверка на 50x, команда: `grep -wP '” 50\d' access_log`  
- Число ответов 50x, комада: `grep -wPc '" 50\d' access_log`

Вывод команд:

```ShellSession
bitnami@debian:/opt/bitnami/apache2/logs$ grep -wP '" 50\d' access_log
bitnami@debian:/opt/bitnami/apache2/logs$ grep -wPc '" 50\d' access_log
0
```

> Примечание: если использовать команду `grep -wP '50\d' access_log` или `grep -w 50[0-9] access_log` то получим искомые комбинации цифр в столбце размера, а не статус-кода ответа:  
> `192.168.41.249 - - [04/Mar/2020:20:28:18 +0000] "GET /gui/themes/default/images/door_open.png HTTP/1.1" 200 508`

##### 6.4 Подсчитать общее количество обращений

- Подсчет числа обращений, команда: `cat access_log | wc -l`  
- Подсчет числа обращений с каждого адреса, скрипт:

```Shell
#!/bin/bash

LOG_FILE='/opt/bitnami/apache2/logs/access_log'

for source_ip in $(cat $LOG_FILE | cut -d' ' -f1 | sort | uniq);
do
    ip_count=$(grep -c $source_ip $LOG_FILE)
    printf "Source ip:\t%s\t\tAccess count:\t%s\n" $source_ip $ip_count
done
```

Выполнение команд и скрипта:

```ShellSession
bitnami@debian:/opt/bitnami/apache2/logs$ cat access_log | wc -l
1676
bitnami@debian:/opt/bitnami/apache2/logs$ ~/bin/count_access.sh
Source ip:      192.168.41.2            Access count:   1607
Source ip:      192.168.41.249          Access count:   757
Source ip:      192.168.41.5            Access count:   72
```

##### 6.5 Определить временные диапазоны лога (первая и последняя записи)

Команды: `head -1 access_log; tail -1 access_log`

Выполнение команд:

```ShellSession
bitnami@debian:/opt/bitnami/apache2/logs$ head -1 access_log; tail -1 access_log
192.168.41.2 - - [04/Mar/2020:19:27:35 +0000] "GET / HTTP/1.1" 200 122
192.168.41.5 - - [04/Mar/2020:21:17:03 +0000] "-" 408 -
```
