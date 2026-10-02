from django.db import models

class Student(models.Model):
    BRANCHES = [("CSE", "CSE"), ("IT", "IT"), ("ECE", "ECE")]

    name = models.CharField(max_length=120)
    email = models.EmailField(unique=True)
    branch = models.CharField(max_length=3, choices=BRANCHES)

    def __str__(self):
        return self.name
