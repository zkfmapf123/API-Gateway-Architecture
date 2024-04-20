import express from 'express'

const app = express()
app.get("/", (req, res) => {
    console.log("hello world")
    return res.status(200).json("hello world")
})
app.get("/health", (req, res) => {
    console.log("health check")
    return res.status(200).json("success")
})

app.get("/a", (req, res) => { return res.status(200).json("a") })
app.get("/b", (req, res) => { return res.status(200).json("b") })
app.get("/c", (req, res) => { return res.status(200).json("c") })
app.get("/d", (req, res) => { return res.status(200).json("d") })
app.listen(3000, () => {
    console.log("connect to port on 3000")
})
