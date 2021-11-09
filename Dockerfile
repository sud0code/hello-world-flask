FROM python:slim-buster

COPY . /flask-app

WORKDIR /flask-app

RUN pip3 install -r requirements.txt

CMD ["python3","app.py"]

EXPOSE 80