FROM python:3.10-slim

RUN pip install --upgrade pip && pip install --no-cache-dir \
  django-cms \
  django-rest-framework \
  psycopg2-binary \
  gunicorn

WORKDIR /app

COPY . .

ENV DJANGO_SETTING_MODULE=PointOfSales.settings
ENV DATABASE_URL=postgres://user:password@localhost:5432/POS

RUN python manage.py migrate

CMD ["gunicord", "-w", "4", "-b", ":8000", "pointofsales.wsgi:application"]

EXPOSE 8000