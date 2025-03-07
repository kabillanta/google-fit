import datetime
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/fetch-fitness-data', methods=['POST'])
def fetch_fitness_data():
    data = request.json
    access_token = data.get('access_token')
    now = datetime.datetime.now(datetime.timezone.utc)
    start_of_day = datetime.datetime(now.year, now.month, now.day)
    start_time_millis = int(start_of_day.timestamp() * 1000)
    end_time_millis = int(now.timestamp() * 1000)

    url = "https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    body = {
        "aggregateBy": [
            {
                "dataTypeName": "com.google.step_count.delta"
            }
        ],
        "bucketByTime": {"durationMillis": 86400000}, 
        "startTimeMillis": start_time_millis,
        "endTimeMillis": end_time_millis
    }

    response = requests.post(url, headers=headers, json=body)
    if response.status_code == 200:
        fitness_data = response.json()
        total_steps = 0
        for bucket in fitness_data['bucket']:
            for dataset in bucket['dataset']:
                for point in dataset['point']:
                    for value in point['value']:
                        total_steps += value['intVal']

        return jsonify({
            "steps": total_steps,
            "message": "Fetched today's step count"
        })
    else:
        return jsonify({"error": response.json()}), response.status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
