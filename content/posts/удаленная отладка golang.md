---
title: Удалённая отладка Golang
date: 2018-08-03
categories: [Development, Golang]
excludeRelatedPost: true
tags:
- Debug
- Golang
---

Недавно довелось столкнуться с необходимостью отладки (запуска дебагера) программы, которая работает
в Docker-контейнере внутри Vagrant'а. Как оказалось, сделать это достаточно просто. Далее будет
небольшая инструкция, как этого добиться.

<!--more-->

1. Для удалённой отладки Goland предлагает использовать Delve. Поэтому, устанавливаем его.

2. Выполняем команду:

```shell
dlv debug --headless --listen=:1234 --api-version=2
```

Эта команда компилирует программу с отключением оптимизации, запускает и прикрепляет к ней дебагер.
Дебагер запускается в не интерактивном режиме и слушает порт 1234 Есть альтернативный способ.
Компилируем программу следующим образом:

```shell
go build -gcflags "all=-N -l" github.com/app/demo
```

(для Go версии 1.10+)
либо:

```shell
go build -gcflags "-N -l" github.com/app/demo
```

3. В Goland заходим в настройки конфигурации запуска (Run/Debug Configuration):

![Goland Run/Debug configuration](/img/go-remote-debug/goland_run_config.png)

4. Добавляем новую конфигурацию: Go Remote

![Go Remote](/img/go-remote-debug/go_remote.png)

Указываем host vagrant'а и порт, который использовали при запуске Delve (п. 2). Сохраняем, закрываем
настройки

5. Запускаем режим дебага в Goland (Run → Debug). После этого будет непосредственно запущена
   программа, и теперь к ней можно обращаться обычным образом (например, из браузера).

Пример команды, запускающей таким образом программу внутри докера:

```shell
docker run --name your_programm -p 8080:8080 -p 6789:6789 -v "$PWD":/your_package_name -e GOPATH=/your_gopath -w /your_package_name golang:1.10 bash -c "go build -gcflags='all=-N -l' your_package_name && ./bin/dlv --listen=:6789 --headless=true --api-version=2 exec ./your_programm"
```

Обратите внимание, что тут указывается два порта - для обычных запросов к программе (8080) и для
delve (6789). Не забываем указать актуальный путь к dlv (в моём случае: ./bin/dlv).

<Remark></Remark>