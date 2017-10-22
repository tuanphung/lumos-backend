FROM swift:4.0

RUN apt-get update
RUN apt-get install libpq-dev -y

ADD Package.swift /tmp/Package.swift
RUN cd /tmp && swift package resolve
RUN mkdir -p /usr/src/lumos-backend && cp -a /tmp/.build /usr/src/lumos-backend

WORKDIR /usr/src/lumos-backend
ADD . /usr/src/lumos-backend

RUN swift build -Xcc -O -Xcc -I/usr/include/postgresql --configuration release

CMD [ ".build/release/Run" ]