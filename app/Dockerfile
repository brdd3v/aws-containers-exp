FROM python:3.10-alpine

WORKDIR /code

COPY requirements.txt .

RUN pip3 install -r requirements.txt --no-cache-dir

COPY . .

EXPOSE 5000

CMD [ "python", "flask-app/app.py" ]
