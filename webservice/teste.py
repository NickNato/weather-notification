import requests

response = requests.get('http://localhost:5000/clima/SP')
print(response.json())