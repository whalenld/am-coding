import React, { useEffect, useState } from 'react';

const Activities = () => {
  const [activities, setActivities] = useState([]);
  const endpoint = `https://${process.env.REACT_APP_CODESPACE_NAME}-8000.app.github.dev/api/activities/`;

  useEffect(() => {
    fetch(endpoint)
      .then(res => res.json())
      .then(data => {
        console.log('Fetched activities from:', endpoint);
        console.log('Activities data:', data);
        setActivities(Array.isArray(data) ? data : data.results || []);
      })
      .catch(err => console.error('Error fetching activities:', err));
  }, [endpoint]);

  return (
    <div>
      <h2>Activities</h2>
      <table className="table table-striped">
        <thead>
          <tr>
            <th>#</th>
            <th>User</th>
            <th>Type</th>
            <th>Duration (min)</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          {activities.map((activity, idx) => (
            <tr key={activity.id || idx}>
              <td>{idx + 1}</td>
              <td>{activity.user?.name || '-'}</td>
              <td>{activity.type || '-'}</td>
              <td>{activity.duration ?? '-'}</td>
              <td>{activity.date || '-'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default Activities;
