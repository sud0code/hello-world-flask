FROM python:slim-buster

COPY . /flask-app

WORKDIR /flask-app

RUN pip install -r requirements.txt

CMD ["python","app.py"]

EXPOSE 5000