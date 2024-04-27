import express from 'express'

const friends = {
    "limjeahyock": "developer",
    "sinjunghyoen": "police",
    "kimhyeoncheol": "police"
}

const app = express()
app.get("/", (req, res) => {
    console.log("hello world")
    return res.status(200).json("hello world")
})
app.get("/health", (req, res) => {
    console.log("health check")
    return res.status(200).json("success")
})

app.get("/friends", (req, res) => {
    return res.status(200).json(friends)
})

app.get("/friends/sum", (req, res) => {
    return res.status(200).json({
        result: Object.values(friends).length
    })
})

app.get("/friends/developer", (req, res) => {
    return res.status(200).json({
        result: Object.values(friends).filter((it) => it === "developer").length
    })
})

app.get("/friends/police", (req, res) => {
    return res.status(200).json({
        result: Object.values(friends).filter((it) => it === "police").length
    })
})

app.listen(3000, () => {
    console.log("connect to port on 3000")
})
