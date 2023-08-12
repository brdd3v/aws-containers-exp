FROM python:3.10-alpine

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /code

COPY requirements.txt .

RUN pip3 install -r requirements.txt --no-cache-dir

COPY . .

EXPOSE 5000

USER appuser

CMD [ "python", "flask-app/app.py" ]
