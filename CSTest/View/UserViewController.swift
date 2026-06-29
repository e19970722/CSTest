//
//  ViewController.swift
//  CSTest
//
//  Created by Yen Lin on 2026/6/29.
//

import UIKit
import Combine

class UserViewController: UIViewController {
    
    private let vm = UserViewModel()
    private let input: PassthroughSubject<UserViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "\(UserTableViewCell.self)")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        input.send(.fetchItems)
    }

    private func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func bindViewModel() {
        let output = vm.transform(input: input.eraseToAnyPublisher())
        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .fetchItemsSuccess:
                    self.tableView.reloadData()
                    
                case .fetchItemsFailed(let error):
                    self.showAlert(text: error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    private func showAlert(text: String) {
        let alertVC = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertVC.addAction(okAction)
        self.present(alertVC, animated: true)
    }
}

// MARK: - Table View Delegate

extension UserViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(UserTableViewCell.self)") as? UserTableViewCell else { return UITableViewCell() }
        
        guard indexPath.row < vm.users.count else { return UITableViewCell() }
        let currentUser = vm.users[indexPath.row]
        cell.updateUI(text: """
            id: \(currentUser.id ?? 0)
            name: \(currentUser.name ?? "")
            userName: \(currentUser.username ?? "")
            email: \(currentUser.email ?? "")
            address: \(currentUser.address?.street ?? "") \(currentUser.address?.suite ?? "") \(currentUser.address?.city ?? "") \(currentUser.address?.zipcode ?? "") \(currentUser.address?.geo?.lat ?? "") \(currentUser.address?.geo?.lng ?? "")
            phone: \(currentUser.phone ?? "")
            website: \(currentUser.website ?? "")
            company: \(currentUser.company?.name ?? "") \(currentUser.company?.catchPhrase ?? "") \(currentUser.company?.bs ?? "")
            """
        )
        return cell
    }
}
