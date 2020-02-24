#!/bin/bash

# Текст для отображению в случае возникновения ошибок
ARG_ERR="Not enough arguments"
DIR_IN_ERR="Can not access or find folder: "
OUT_DIR_ERR="Cannot create output dir: "
FILES_COUNT_ERR="Number of files in source and compare folders must be the same"

# Общее описание скрипта, отображается при вызове скрипта без аргументов
usage(){
    cat <<-EOF
    This script compares images in two directories and writes the results in the third one.
    The number of files in 'source and' 'to compare' directories must be the same.
    Imagefile names must begin with 'prefix_' For example: 'p1_image.jpg' or '01_image.jpg'

    Usage: $0 [source_images_dir] [to_compare_images_dir] [results_dir]
    
    Examples:
        $0 src screens results
EOF
}

# Отображение текста ошибки и завершение скрипта с кодом ошибки (не 0)
print_err(){
    >&2 echo $1
    [[ $2 -eq 0 ]] && usage
    [[ $# -gt 2 ]] && exit $3
}

# Если аргументов не 3 - выход с ошибкой 1
[[ ! $# == 3 ]] && print_err "$ARG_ERR" 0 1

# Если одной из заданных директорий нет - выход с ошибкой 2
check_dir(){
    [[ -d $1 ]] || print_err "$DIR_IN_ERR$1" 1 2
}

src_dir=$1
check_dir $src_dir

cmp_dir=$2
check_dir $cmp_dir

# Если невозможно создать директорию для записи результатов - выход с ошибкой 3
out_dir=$3
mkdir $out_dir &>/dev/null || print_err "$OUT_DIR_ERR$out_dir" 1 3

# Запись списков изображений во временные файлы
find $src_dir -type f|sort > .src
find $cmp_dir -type f|sort > .cmp

# Если число изображений во входящих директориях не совпадает - - выход с ошибкой 4
[[ ! `cat .src|wc -l` == `cat .cmp|wc -l` ]] && print_err "$FILES_COUNT_ERR" 1 4

# Создание временной директории
mkdir img_tmp

for i in $(seq 1 `cat .src|wc -l`); do
    echo $i of `cat .src|wc -l`:

    src_image=$(sed -n "$i"p .src)
    src_size=$(identify -format "%wx%h" $src_image)
    printf "Source image:\t\t%s\nSource image size:\t%s\n" $src_image $src_size

    cmp_image=$(sed -n "$i"p .cmp)
    cmp_size=$(identify -format "%wx%h" $cmp_image)
    printf "Compare image:\t\t%s\nCompare image size:\t%s\n" $cmp_image $cmp_size
    
    # Если размеры эталонного и изображения для сравнения не совпадают
    # то размер изображения для сравнения будет приведен к размеру эталонного без удаления исходного
    if [[ ! $src_size == $cmp_size ]]; then
        cmp_image=$(sed -n "$i"p .cmp|awk -F/ '{print $NF}')
        echo ...Sizes not equal, resing \'$cmp_image\' to \'$src_size\'
        convert $(sed -n "$i"p .cmp) -resize $src_size! img_tmp/$cmp_image
        cmp_image=img_tmp/$cmp_image
    fi        
    
    prefix=$(sed -n "$i"p .src|awk -F/ '{print $NF}'|cut -d_ -f1)

    compare -compose src $src_image $cmp_image $out_dir/${prefix}_compare_result.jpg
    printf "Compare result:\t\t%s\n\n" "$out_dir/${prefix}_compare_result.jpg"
done

rm .src .cmp
rm -r img_tmp

echo Done
