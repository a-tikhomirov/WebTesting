#!/bin/bash

# Паттерн строки с URL адресом
LINK_STR='^--'
# Паттерн строки со статусом
STATUS_STR='(^HTTP request sent)|(^HTTP-запрос отправлен)'

# Имя временного файла в оперативной памяти
LINKS_TMP='/dev/shm/.links'
# Имя файла для всех ссылок
LINKS_ALL='links_all.txt'
# Имя файла для ссылок с кодами не 200, 301, 203
LINKS_ERR='links_broken.txt'

# Переменная используется для отсутствия дубликатов проверок
LINK_PREV=""
# Переменная используется для продолжения цикла если найдена ссылка
LINK_FOUNDED=1

# Паттерн для определения валидной ссылки
CODE_PTRN='(200|301|302)'

# Создание/перезапись файлов для хранения результатов
> $LINKS_TMP
echo `date` > $LINKS_ALL
echo `date` > $LINKS_ERR

[[ $# == 2 ]] && DEPTH=$2 || DEPTH='inf'

# Рекурсивная проверка статусов всех ссылок на сайте с бесконечной (по умолчанию) или заданной глубиной
# Запись строк с URL адресом и статусом в файл .links
( wget --spider --force-html -r -l $DEPTH -nd $1 2>&1 & echo $! >&3 ) 3>pid | grep -P "($LINK_STR)|$STATUS_STR" > $LINKS_TMP &
WPID=`cat pid`
rm pid

echo Checking links...

trap clean_stop INT

function clean_stop() {
    printf "\n Trapped CTRL-C\n"
    kill $WPID
}

function check_done() {
    echo `date` >> $LINKS_ALL
    echo `date` >> $LINKS_ERR
    printf "\nChecked %s links\n" $((`cat $LINKS_ALL | wc -l` - 2))
}

# Построчное чтение файла
tail -0f $LINKS_TMP | while read str
do
    # Проверка - содержит ли текущая строка URL адрес
    temp_str=`echo $str | grep "$LINK_STR"`
    [[ $? -eq 0 ]] &&
        link=`echo $temp_str | awk '{ print $3 }'` &&
        LINK_FOUNDED=0

    if [ ! "$link" == "$LINK_PREV" ]; then
        # Вывод в stdout текущего действия по проверке ссылок
        echo $str

        # Если был найден URL адрес - записать в файл и продолжить
        [[ $LINK_FOUNDED -eq 0 ]] &&
            printf "%s\t" $link >> $LINKS_ALL &&
            LINK_FOUNDED=1 &&
            continue

        # Проверка - содержит ли текущая строка код статуса
        temp_str=`echo $str | grep -P "$STATUS_STR"`
        if [[ $? -eq 0 ]]; then
            # Если был найден код статуса - запись в файл
            status_code=`echo $temp_str | awk -F. '{print $NF}' | cut -c 2-` &&
                printf "%s\n" "$status_code" >> $LINKS_ALL

            # Проверка кода статуса на валидность
            # Если статус не 200, 301, 203 - запись в файл с битыми ссылками
            echo $status_code | grep -P "$CODE_PTRN" > /dev/null ||
                printf "%s\t\t%s\n" $link "$status_code" >> $LINKS_ERR

            # Вспомогательная переменная для пропуска повторных
            # проверок URL адреса (которые проводятся для поиска ссылок по URL)
            LINK_PREV=$link
        fi
    fi
    kill -0 $WPID &>/dev/null || break
done

check_done
