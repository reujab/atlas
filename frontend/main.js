const { app, BrowserWindow } = require("electron")

app.whenReady().then(() => {
  const mainWindow = new BrowserWindow({
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      enableRemoteModule: true,
    },
  })

  mainWindow.loadFile("dist/index.html")
})

app.on("window-all-closed", () => {
  app.quit()
})
