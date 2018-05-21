/*
 Developer : Warren Seto
 Classes   : SearchFilterVC
 Project   : Players App (v2)
 */

import UIKit

final class SearchFilterVC: UITableViewController {

    
    // MARK: Properties
    
    private let filterTitles = ["Order By", "Duration"],
        filterOptions = [["Relevance", "Date Published", "View Count", "Rating"], ["All", "< 4 minutes", "> 20 minutes"]],
        filters = [["", "date", "viewCount", "rating"], ["", "short", "long"]]
    
    lazy var selectedOptions = [0, 0, 0]
    
    var delegate:SearchProtocol?
    
    
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
        
        if selectedOptions[0] != 0 {
            filtersArray.append("order=\(filters[0][selectedOptions[0]])")
        }
        
        if selectedOptions[1] != 0 {
            filtersArray.append("videoDuration=\(filters[1][selectedOptions[1]])")
        }

        return filtersArray.isEmpty ? " " : filtersArray.joined(separator: "&")
    }
    
    
    // MARK: SearchFilterVC Implementation
    
    private func setViewController(with traitCollection:UITraitCollection) {
        self.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: traitCollection.verticalSizeClass == .compact ? 200 : 400)
    }
    
    
    // MARK: UITableViewDataSource Implementation
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return filterOptions.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterOptions[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filterTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return {
            $0.textLabel?.text = filterOptions[indexPath.section][indexPath.row]
            $0.accessoryType = selectedOptions[indexPath.section] == indexPath.row ? .checkmark : .none
            
            return $0
        } (tableView.dequeueReusableCell(withIdentifier: "SearchFilterRow", for: indexPath))
    }
    
    
    // MARK: UITableViewDelegate Implementation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Update the TableView UI
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.cellForRow(at: IndexPath(item: selectedOptions[indexPath.section], section: indexPath.section))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        selectedOptions[indexPath.section] = indexPath.row
        
        delegate?.applyFilters(newFilter: serializeFilters(), newOptions: selectedOptions)
    }
}
