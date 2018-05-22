/*
 Developer : Warren Seto
 Classes   : SearchFilterVC
 Project   : Players App (v2)
 */

import UIKit

final class SearchFilterVC: UITableViewController {

    
    // MARK: Properties
    
    private let titles : [String] = ["Order By", "Duration"]
    
    private let options : [[String]] = [["Relevance", "Date Published", "View Count", "Rating"], ["All", "< 4 minutes", "> 20 minutes"]],
                filters = [["", "date", "viewCount", "rating"], ["", "short", "long"]]
    
    var selected : [Int]!
    
    var delegate : SearchProtocol?
    
    
    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        setViewController(with: self.traitCollection)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        setViewController(with: newCollection)
    }
    
    private func serializeFilters() -> String {

        var filtersArray:[String] = []
        
        if selected[0] != 0 {
            filtersArray.append("order=\(filters[0][selected[0]])")
        }
        
        if selected[1] != 0 {
            filtersArray.append("videoDuration=\(filters[1][selected[1]])")
        }

        return filtersArray.isEmpty ? " " : filtersArray.joined(separator: "&")
    }
    
    
    // MARK: SearchFilterVC Implementation
    
    private func setViewController(with traitCollection:UITraitCollection) {
        self.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: traitCollection.verticalSizeClass == .compact ? 200 : 400)
    }
    
    
    // MARK: UITableViewDataSource Implementation
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titles[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return {
            $0.textLabel?.text = options[indexPath.section][indexPath.row]
            $0.accessoryType = selected[indexPath.section] == indexPath.row ? .checkmark : .none
            
            return $0
        } (tableView.dequeueReusableCell(withIdentifier: "SearchFilterRow", for: indexPath))
    }
    
    
    // MARK: UITableViewDelegate Implementation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Update the TableView UI
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.cellForRow(at: IndexPath(item: selected[indexPath.section], section: indexPath.section))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        selected[indexPath.section] = indexPath.row
        
        delegate?.applyFilters(newFilter: serializeFilters(), newOptions: selected)
    }
}
