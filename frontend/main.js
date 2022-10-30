const { app, BrowserWindow } = require("electron");

app.whenReady().then(() => {
	const mainWindow = new BrowserWindow({
		webPreferences: {
			nodeIntegration: true,
			contextIsolation: false,
			enableRemoteModule: true,
		},
	});

	mainWindow.setMenuBarVisibility(false);
	mainWindow.maximize();
	mainWindow.loadFile("http/index.html");
});

app.on("window-all-closed", () => {
	app.quit();
});
