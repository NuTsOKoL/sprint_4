import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    private let presenter = MovieQuizPresenter()
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertProtocol?
    private var statisticService: StatisticServiceProtocol?
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 20
        
        alertPresenter = AlertPresenter(viewController: self)
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticServiceImplementation()
        showLoadingIndicator()
        questionFactory?.loadData()
        
        presenter.viewController = self
        self.activityIndicator.hidesWhenStopped = true
    }
    //MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    //MARK: - yes/no button
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
//        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
//        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
    }
    
     func changeStateButtons(isEnabled: Bool) {
            yesButton.isEnabled = isEnabled
            noButton.isEnabled = isEnabled
        }
    
    //MARK: activityIndicator
    private func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func didLoadDataFromServer() {
        questionFactory?.requestNextQuestion()
        hideLoadingIndicator()
    }
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
     func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        hideLoadingIndicator()
    }
    
     func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            showResult()
        } else {
            presenter.switchToNextQuestion()
            showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func showResult() {
        statisticService?.store(correct: correctAnswers, total: presenter.questionAmount)
        
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: resultMessage(),
            buttonText: "Сыграть еще раз") { [weak self] in
                self?.presenter.resetQuestionIndex()
                self?.correctAnswers = 0
                self?.showLoadingIndicator()
                self?.questionFactory?.requestNextQuestion()
            }
        alertPresenter?.show(alertModel: alertModel)
    }
    
    private func resultMessage() -> String {
        guard let statisticService = statisticService, let bestGame = statisticService.bestGame else {
            return ""
        }
        let totalPlayCount = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResult = "Ваш результат: \(correctAnswers)/\(presenter.questionAmount) "
        let averageAccuracy = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
        let bestGameInfo = "Рекорд:  \(bestGame.correct)/10" + "(\(bestGame.date.dateTimeString))"
        let resultMessage = [currentGameResult, totalPlayCount, bestGameInfo,
                             averageAccuracy].joined(separator: "\n")
        return resultMessage
    }
    
    //MARK: alertError
    private func showNetworkError(message: String) {
        hideLoadingIndicator()

        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        alertPresenter?.show(alertModel: model)
    }
}
