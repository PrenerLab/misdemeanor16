#!/usr/bin/env bash

# create csv folders
mkdir data/raw/stlmpd/csv/2016
mkdir data/raw/stlmpd/csv/2017
mkdir data/raw/stlmpd/csv/2018

# copy html files new directory for csv
cp -r data/raw/stlmpd/html/2016/* data/raw/stlmpd/csv/2016

# change file extensions
for file in data/raw/stlmpd/csv/2016/*.html
do
  mv "$file" "${file%%.*}.${file##*.}"
done

for file in data/raw/stlmpd/csv/2016/*.html
do
  mv "$file" "${file%.html}.csv"
done

# copy html files new directory for csv
cp -r data/raw/stlmpd/html/2017/* data/raw/stlmpd/csv/2017

# change file extensions
for file in data/raw/stlmpd/csv/2017/*.html
do
  mv "$file" "${file%%.*}.${file##*.}"
done

for file in data/raw/stlmpd/csv/2017/*.html
do
  mv "$file" "${file%.html}.csv"
done

# copy html files new directory for csv
cp -r data/raw/stlmpd/html/2018/* data/raw/stlmpd/csv/2018

# change file extensions
for file in data/raw/stlmpd/csv/2018/*.html
do
  mv "$file" "${file%%.*}.${file##*.}"
done

for file in data/raw/stlmpd/csv/2018/*.html
do
  mv "$file" "${file%.html}.csv"
done