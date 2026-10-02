from rest_framework import status
from rest_framework.test import APITestCase

class StudentApiTests(APITestCase):
    def test_student_crud(self):
        url = "/api/students/"
        data = {"name": "Sam Lee", "email": "sam@example.com", "branch": "CSE"}
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        student_id = response.data["id"]
        self.assertEqual(self.client.get(url).data[0]["name"], "Sam Lee")
        self.assertEqual(self.client.patch(f"{url}{student_id}/", {"branch": "IT"}, format="json").data["branch"], "IT")
        self.assertEqual(self.client.delete(f"{url}{student_id}/").status_code, status.HTTP_204_NO_CONTENT)
