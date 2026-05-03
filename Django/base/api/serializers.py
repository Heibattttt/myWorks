from rest_framework.serializers import ModelSerializer
from base.models import Roomm

class RoomSerializer(ModelSerializer):
    class Meta:
        model = Roomm
        fields = '__all__'