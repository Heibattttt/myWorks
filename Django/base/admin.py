from django.contrib import admin

# Register your models here.
from .models import Roomm,Message,Topic

admin.site.register(Roomm) 
admin.site.register(Message) 
admin.site.register(Topic) 