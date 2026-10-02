# API Reference

Base URL: `http://127.0.0.1:8000/api`

A student has an automatically assigned `id`, `name`, unique `email`, and a `branch` (`CSE`, `IT`, or `ECE`). Requests and responses use JSON.

| Method | Endpoint | Action | Success |
| --- | --- | --- | --- |
| GET | `/students/` | List students | 200 |
| POST | `/students/` | Add student | 201 |
| GET | `/students/{id}/` | Get one student | 200 |
| PUT / PATCH | `/students/{id}/` | Update student | 200 |
| DELETE | `/students/{id}/` | Remove student | 204 |

Example create request:

```json
{
  "name": "Sam Lee",
  "email": "sam@example.com",
  "branch": "CSE"
}
```

Invalid fields or duplicate emails return `400`; an unknown student ID returns `404`.
