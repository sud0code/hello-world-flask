FROM python:slim-buster

WORKDIR /flask-app

ADD . /flask-app

RUN pip install -r requirements.txt

CMD ["python","app.py"]

EXPOSE 5000