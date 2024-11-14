import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from requests.exceptions import RequestException

# Import your FastAPI app
from src.main import app

class TestFastAPIEndpoints(unittest.TestCase):
    def setUp(self):
        """Set up test client before each test case."""
        self.client = TestClient(app)

    def test_health_check(self):
        """Test the health check endpoint."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "healthy"})

    @patch('requests.get')
    def test_get_public_ip_success(self, mock_get):
        """Test successful IP address retrieval."""
        # Mock the successful response from ipify
        mock_get.return_value.text = "192.168.1.1"
        
        response = self.client.get("/")
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"public_ip": "192.168.1.1"})
        mock_get.assert_called_once_with('https://api.ipify.org', timeout=5)

    @patch('requests.get')
    def test_get_public_ip_failure(self, mock_get):
        """Test IP address retrieval failure."""
        # Mock the request exception
        mock_get.side_effect = RequestException("Connection error")
        
        response = self.client.get("/")
        
        self.assertEqual(response.status_code, 200)  # FastAPI still returns 200 in this case
        self.assertEqual(response.json(), {"error": "Unable to retrieve IP address"})
        mock_get.assert_called_once_with('https://api.ipify.org', timeout=5)

    def test_invalid_endpoint(self):
        """Test accessing an invalid endpoint."""
        response = self.client.get("/invalid")
        self.assertEqual(response.status_code, 404)

if __name__ == '__main__':
    unittest.main()