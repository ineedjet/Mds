import XCTest

extension XCUIElementQuery {
    func element(withLabel label: String) -> XCUIElement {
        return element(matching: NSPredicate(format: "label == %@", label))
    }
    func element(withIdentifier identifier: String) -> XCUIElement {
        return element(matching: NSPredicate(format: "identifier == %@", identifier))
    }
    func element(withLabel label: String, or otherLabel: String) -> XCUIElement {
        return element(matching: NSPredicate(format: "(label == %@) OR (label == %@)", label, otherLabel))
    }
}

class MdsUITests: XCTestCase {
    private var app: XCUIApplication!
    private let simulator: String = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] ?? "UNKNOWN"
    private let screenshotDir: URL? = {
        guard let env = ProcessInfo().environment["SCREENSHOT_DIR"] else {
            return nil
        }
        do {
            try FileManager.default.createDirectory(atPath: env, withIntermediateDirectories: true)
        }
        catch {
            fatalError("Failed to create directory: \(error)")
        }
        return URL(fileURLWithPath: env)
    }()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-clean"]
        app.launch()
    }

    private func snapshot(_ name: String) {
        guard let screenshotDir = screenshotDir else {
            return
        }
        let screenshot = app.windows.firstMatch.screenshot()
        let path = screenshotDir.appendingPathComponent("\(simulator)-\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: path)
        } catch let error {
            print("Problem writing screenshot: \(name) to \(path)")
            print(error)
        }
    }

    func testMainScreen() {
        let mainTable = app.tables.firstMatch
        let treeCell = mainTable.cells.element(boundBy: 4)
        treeCell.tap()
        let alert = app.sheets.firstMatch
        alert.buttons["Загрузить (4 МБ)"].tap()
        treeCell.tap()
        alert.buttons["Начать воспроизведение"].tap()

        let leziroffCell = mainTable.cells.element(boundBy: 1)
        leziroffCell.tap()
        alert.buttons.element(withLabel: "Загрузить (1.2 МБ)", or: "Загрузить (1,2 МБ)").tap()

        let pauseButton = app.buttons["Пауза"].firstMatch
        XCTAssert(pauseButton.waitForExistence(timeout: 10))
        snapshot("0MainView")

        let sleepTimerButton = app.buttons["Таймер сна"].firstMatch
        sleepTimerButton.tap()
        app.buttons["Через 1 минуту"].tap()

        app.tabBars.buttons["Поиск"].tap()
        app.searchFields["Модель для сборки"].tap()
        sleep(1)

        let kbd = app.keyboards
        if UIDevice.current.userInterfaceIdiom == .phone {
            kbd.keys["more"].tap()
        }
        kbd.keys["2"].tap()
        kbd.keys["4"].tap()
        kbd.keys["3"].tap()
        kbd.keys["0"].tap()
        if UIDevice.current.userInterfaceIdiom == .phone {
            kbd.keys["more"].tap()
        }
        sleep(1)
        snapshot("2Search")

        let y2430Cell = app.tables["Результаты поиска"].cells.element(boundBy: 0)
        y2430Cell.tap()
        alert.buttons.element(withLabel: "Загрузить (15.4 МБ)", or: "Загрузить (15,4 МБ)").tap()

        app.buttons["Отменить"].tap()
        app.tabBars.buttons["Загрузки"].tap()
        sleep(1)
        snapshot("3Downloads")

        app.tabBars.buttons["Все записи"].tap()
        app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 1)
        app.navigationBars.buttons["Настройки"].tap()
        app.switches.firstMatch.tap()
        app.navigationBars.buttons["Готово"].tap()

        let swiftCell = mainTable.cells.element(boundBy: 4)
        swiftCell.tap()
        alert.buttons["Начать воспроизведение"].tap()

        XCTAssert(app.buttons["Пауза"].firstMatch.waitForExistence(timeout: 60))
        sleepTimerButton.tap()
        XCTAssert(app.buttons["Через 60 минут"].waitForExistence(timeout: 10))
        snapshot("1SleepTimer")
    }
}
