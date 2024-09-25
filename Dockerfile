FROM python:3.10-slim

RUN apt-get update && apt-get install -y libq-dev && apt-get clean
RUN pip install --upgrade pip && pip install --no-cache-dir \
  django-cms \
  django-rest-framework \
  psycopg2-binary \
  gunicorn

WORKDIR /app

COPY requirements.in .

RUN pip install -r requirement.in

COPY . .

ENV DJANGO_SETTING_MODULE=PointOfSales.settings
ENV DATABASE_URL=postgres://user:password@localhost:5432/POS

RUN python manage.py makemigrations && python manage.py migrate

CMD ["gunicord", "-w", "4", "-b", ":8000", "pointofsales.wsgi:application"]

EXPOSE 8000