from django.forms import ModelForm
from .models import  Roomm
from django.contrib.auth.models import User

class RoomForm(ModelForm):
    class Meta:
        model=Roomm
        fields='__all__'
        exclude=['host','participants']


class UserForm(ModelForm):
    class Meta:
        model=User
        fields=['username','email']
       