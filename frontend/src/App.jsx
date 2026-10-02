import { useEffect, useState } from "react";

const emptyStudent = { name: "", email: "", branch: "CSE" };

export default function App() {
  const [students, setStudents] = useState([]);
  const [form, setForm] = useState(emptyStudent);
  const [editingId, setEditingId] = useState(null);
  const [error, setError] = useState("");

  async function request(path, options = {}) {
    const response = await fetch(`/api${path}`, {
      ...options,
      headers: { "Content-Type": "application/json", ...options.headers },
    });
    if (!response.ok) {
      const result = await response.json().catch(() => ({}));
      throw new Error(Object.values(result).flat().join(" ") || "Request failed.");
    }
    return response.status === 204 ? null : response.json();
  }

  async function loadStudents() {
    try {
      setStudents(await request("/students/"));
      setError("");
    } catch (err) {
      setError(err.message || "Could not connect to the API.");
    }
  }

  useEffect(() => {
    loadStudents();
  }, []);

  async function handleSubmit(event) {
    event.preventDefault();
    try {
      const student = editingId === null
        ? await request("/students/", { method: "POST", body: JSON.stringify(form) })
        : await request(`/students/${editingId}/`, { method: "PUT", body: JSON.stringify(form) });
      setStudents((current) => editingId === null
        ? [...current, student]
        : current.map((item) => item.id === student.id ? student : item));
      setForm(emptyStudent);
      setEditingId(null);
      setError("");
    } catch (err) {
      setError(err.message || "Could not save the student.");
    }
  }

  function editStudent(student) {
    setForm({ name: student.name, email: student.email, branch: student.branch });
    setEditingId(student.id);
  }

  async function deleteStudent(id) {
    if (!window.confirm("Delete this student?")) return;
    try {
      await request(`/students/${id}/`, { method: "DELETE" });
      setStudents((current) => current.filter((student) => student.id !== id));
    } catch (err) {
      setError(err.message || "Could not delete the student.");
    }
  }

  return (
    <main className="page">
      <header className="heading">
        <p className="eyebrow">STUDENT RECORDS</p>
        <h1>Student Management</h1>
        <p>Add, update, view, or remove student records.</p>
      </header>

      <section className="panel">
        <h2>{editingId === null ? "Add student" : "Edit student"}</h2>
        <form onSubmit={handleSubmit} className="student-form">
          <label>Name<input value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} required maxLength="120" /></label>
          <label>Email<input type="email" value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} required maxLength="254" /></label>
          <label>Branch<select value={form.branch} onChange={(event) => setForm({ ...form, branch: event.target.value })}><option value="CSE">CSE</option><option value="IT">IT</option><option value="ECE">ECE</option></select></label>
          <div className="form-actions"><button className="primary" type="submit">{editingId === null ? "Add student" : "Save changes"}</button>{editingId !== null && <button type="button" onClick={() => { setEditingId(null); setForm(emptyStudent); }}>Cancel</button>}</div>
        </form>
      </section>

      {error && <p className="error" role="alert">{error} <button type="button" onClick={loadStudents}>Retry</button></p>}

      <section className="panel records">
        <div className="list-heading"><h2>Students</h2><span>{students.length} records</span></div>
        {students.length === 0 ? <p className="empty">No students yet.</p> : (
          <div className="table-scroll"><table><thead><tr><th>Name</th><th>Email</th><th>Branch</th><th>Actions</th></tr></thead><tbody>
            {students.map((student) => <tr key={student.id}><td>{student.name}</td><td>{student.email}</td><td>{student.branch}</td><td className="actions"><button type="button" onClick={() => editStudent(student)}>Edit</button><button type="button" className="delete" onClick={() => deleteStudent(student.id)}>Delete</button></td></tr>)}
          </tbody></table></div>
        )}
      </section>
      <footer>React · Django REST Framework · PostgreSQL</footer>
    </main>
  );
}
