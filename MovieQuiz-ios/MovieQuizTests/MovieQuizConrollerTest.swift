import Foundation
import XCTest
@testable import MovieQuiz
final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    func show(quiz step: QuizStepViewModel) {}
    func showResult() {}
    func highlightImageBorder(isCorrectAnswer: Bool) {}
    func noImageBorder() {}
    func showLoadingIndicator() {}
    func hideLoadingIndicator() {}
    func enebleButtons() {}
    func disableButtons() {}
    func showNetworkError(message: String) {}
}
final class MovieQuizPresenterTests: XCTestCase {
    func testPresenterConvertModel() throws {
        let viewControllerMock = MovieQuizViewController()
        let sut = MovieQuizPresenter(viewController: viewControllerMock)
        let emptyData = Data()
        let question = QuizQuestion(image: emptyData, text: "Question Text", correctAnswer: true)
        let viewModel = sut.convert(model: question)
        
        XCTAssertNotNil(viewModel.image)
        XCTAssertEqual(viewModel.question, "Question Text")
        XCTAssertEqual(viewModel.questionNumber, "1/10")
    }
}
