from django.core.management.base import BaseCommand
from octofit_tracker.models import Team, User, Activity, Workout, Leaderboard
from django.db import connection

class Command(BaseCommand):
    help = 'Populate the octofit_db database with test data'

    def handle(self, *args, **options):
        self.stdout.write('Clearing old data...')
        Leaderboard.objects.all().delete()
        Activity.objects.all().delete()
        User.objects.all().delete()
        Team.objects.all().delete()
        Workout.objects.all().delete()

        self.stdout.write('Creating teams...')
        marvel = Team.objects.create(name='Marvel')
        dc = Team.objects.create(name='DC')

        self.stdout.write('Creating users...')
        users = [
            User.objects.create(name='Spider-Man', email='spiderman@marvel.com', team=marvel),
            User.objects.create(name='Iron Man', email='ironman@marvel.com', team=marvel),
            User.objects.create(name='Wonder Woman', email='wonderwoman@dc.com', team=dc),
            User.objects.create(name='Batman', email='batman@dc.com', team=dc),
        ]

        self.stdout.write('Creating activities...')
        Activity.objects.create(user=users[0], type='Running', duration=30, date='2025-10-01')
        Activity.objects.create(user=users[1], type='Cycling', duration=45, date='2025-10-02')
        Activity.objects.create(user=users[2], type='Swimming', duration=60, date='2025-10-03')
        Activity.objects.create(user=users[3], type='Yoga', duration=50, date='2025-10-04')

        self.stdout.write('Creating workouts...')
        Workout.objects.create(name='Hero HIIT', description='High intensity interval training for heroes.', suggested_for='Marvel')
        Workout.objects.create(name='Gotham Strength', description='Strength training for Gotham defenders.', suggested_for='DC')

        self.stdout.write('Creating leaderboard...')
        Leaderboard.objects.create(team=marvel, points=150)
        Leaderboard.objects.create(team=dc, points=120)

        self.stdout.write(self.style.SUCCESS('Database populated with test data.'))

        # Ensure unique index on email
        with connection.cursor() as cursor:
            cursor.execute('db.users.createIndex({ "email": 1 }, { "unique": true })')
        self.stdout.write(self.style.SUCCESS('Ensured unique index on user email.'))
