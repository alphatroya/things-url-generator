FROM swift:5.3.2

WORKDIR /app

COPY . ./

ENTRYPOINT [ "swift", "test" ]
