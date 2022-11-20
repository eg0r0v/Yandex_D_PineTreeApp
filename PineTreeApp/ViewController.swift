//
//  ViewController.swift
//  PineTreeApp
//
//  Created by Илья Егоров on 19.11.2022.
//

import UIKit

protocol ViewModelProtocol: AnyObject {
    init(output: ViewModelOutput)
}

protocol ViewModelOutput: AnyObject {
    func display(message: Message)
}

final class ViewController: UIViewController {
    
    private var alertWindow: UIWindow?

    @IBOutlet private weak var eventStackView: UIStackView!
    @IBOutlet private weak var writeMessageStackView: UIStackView!
    @IBOutlet private weak var textView: UITextView!
    
    private var viewModel: ViewModelProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ConnectionManager.start()
        writeMessageStackView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        askForMode()
    }
    
    private func askForMode() {
        
        let askModeViewController = UIAlertController(
            title: "Выберите режим работы приложения!",
            message: nil,
            preferredStyle: .alert)
        
        let userModeAction = UIAlertAction(title: "Пользователь", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel = NatureLoverViewModel(output: self)
            self.showChooseUserName()
        }
        
        let pineTreeModeAction = UIAlertAction(title: "Сосна", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel = PineTreeViewModel(output: self)
            self.dismissAppAlert()
        }
        askModeViewController.addAction(userModeAction)
        askModeViewController.addAction(pineTreeModeAction)
        
        show(alertController: askModeViewController)
        
    }
    
    private func showChooseUserName() {
        let userNameViewController = UIAlertController(
            title: "Выберите ваше имя",
            message: "Под этим именем будут отправляться сообщения",
            preferredStyle: .alert)

        userNameViewController.addTextField { [weak self] in
            $0.text = (self?.viewModel as? NatureLoverViewModel)?.lastName
            $0.placeholder = "Введите имя"
        }
        
        let userModeAction = UIAlertAction(title: "Проверить", style: .default) { [weak self] _ in
            let textField = userNameViewController.textFields?.first
            guard let text = textField?.text, !text.isEmpty else {
                textField?.becomeFirstResponder()
                return
            }
            userNameViewController.view.isUserInteractionEnabled = false
            
            (self?.viewModel as? NatureLoverViewModel)?.lastName = text
            (self?.viewModel as? NatureLoverViewModel)?.check(
                name: text,
                completion: { isUnique in
                    userNameViewController.view.isUserInteractionEnabled = true
                    if isUnique {
                        self?.writeMessageStackView.isHidden = false
                        self?.dismissAppAlert()
                    } else {
                        self?.showChooseUserName()
                    }
            })
        }
        
        let cancelAction = UIAlertAction(title: "Назад", style: .cancel) { [weak self] _ in
            self?.askForMode()
        }
        
        userNameViewController.addAction(cancelAction)
        userNameViewController.addAction(userModeAction)
        
        show(alertController: userNameViewController)
    }
    
    @IBAction func didTapSendMessage(_ sender: Any) {
        (viewModel as? NatureLoverViewModel)?.send(text: textView.text)
        textView.text = ""
    }
}

extension ViewController {
    private func show(alertController: UIAlertController) {
        if alertWindow == nil {
            alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow?.rootViewController = UIViewController()
            alertWindow?.windowLevel = .alert + 1
        }
        
        alertWindow?.isHidden = false

        if alertWindow?.rootViewController?.presentingViewController == nil {
            alertWindow?.rootViewController?.present(alertController, animated: true)
        } else {
            alertWindow?.rootViewController?.dismiss(animated: true, completion: { [weak self] in
                self?.alertWindow?.rootViewController?.present(alertController, animated: true)
            })
        }
    }
    
    private func dismissAppAlert() {
        alertWindow?.rootViewController?.dismiss(animated: true)
        alertWindow?.isHidden = true
    }
}

extension ViewController: ViewModelOutput {
    func display(message: Message) {
        let eventLabel = UILabel()
        eventLabel.text = [message.senderId, message.message].compactMap({ $0 }).joined(separator: ": ")
        eventLabel.numberOfLines = 0
        eventLabel.lineBreakMode = .byWordWrapping
        
        eventStackView.addArrangedSubview(eventLabel)
    }
}
