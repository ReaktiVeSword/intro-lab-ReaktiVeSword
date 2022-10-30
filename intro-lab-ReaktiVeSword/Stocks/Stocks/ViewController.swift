//
//  ViewController.swift
//  Stocks
//
//  Created by Булат Хасанов on 03.09.2021.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if self.companiesFromService.count > 1 {
            return self.companiesFromService.keys.count;
        }
        return self.companies.keys.count;
        
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if self.companiesFromService.count > 1 {
            return Array(self.companiesFromService.keys)[row];
        }
        return Array(self.companies.keys)[row];
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.activityIndicator.startAnimating()
        var selectedSymbol: String
        if self.companiesFromService.count > 1 {
            selectedSymbol = Array(self.companiesFromService.values)[row]
        } else {
            selectedSymbol = Array(self.companies.values)[row]
        }
        self.requestQuote(for: selectedSymbol)
        self.requestLogoUrlQuote(for: selectedSymbol)
        self.companiesFromService[""] = nil
        self.companyPickerView.reloadAllComponents()
    }
    

    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    
    private var companiesFromService: [String: String] = ["":""]
    private var companies: [String: String] = ["Apple": "AAPL",
                                               "Microsoft": "MSFT",
                                               "Google": "GOOG",
                                               "Amazon": "AMZN",
                                               "Facebook": "FB",
                                               "Nvidia": "NVDA" ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestCompaniesQuote()
        
        self.companyPickerView.dataSource = self;
        self.companyPickerView.delegate = self;
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestQuoteUpdate()
    }
    
    private func requestQuoteUpdate(){
        self.activityIndicator.startAnimating()
        self.companyNameLabel.text = "-"
        self.companySymbolLabel.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.text = "-"
        
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(self.companies.values)[selectedRow]
        self.requestQuote(for: selectedSymbol)
        self.requestLogoUrlQuote(for: selectedSymbol)
    }
    
    private func requestCompaniesQuote(){
        let url = URL(string: "https://cloud.iexapis.com/stable/stock//market/list/gainers?&token=pk_fafd02eea972436fb8e1548832f7da0d")!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            data, response, error in
                guard
                    error == nil,
                    (response as? HTTPURLResponse)?.statusCode == 200,
                    let data = data
                else {
                    print("Network error")
                    return
                }
            DispatchQueue.main.async{
                self.parseCompaniesQuote(data: data)}
        }
        DispatchQueue.main.async{
            dataTask.resume()}
    }
    
    private func parseCompaniesQuote(data: Data){
        let decoder = JSONDecoder()
        do {
            let companies = try decoder.decode([Company].self, from: data)
            for item in companies {
                self.companiesFromService[item.companyName] = item.symbol
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func requestQuote(for symbol: String){
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?&token=pk_fafd02eea972436fb8e1548832f7da0d")!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            data, response, error in
                guard
                    error == nil,
                    (response as? HTTPURLResponse)?.statusCode == 200,
                    let data = data
                else {
                    print("Network error")
                    return
                }
            
            self.parseQuote(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseQuote(data: Data){
        do{
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else{
                print("Invalid JSON format")
                return
            }
            
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName, symbol: companySymbol, price: price, priceChange: priceChange)
            }
        } catch{
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double){
        self.activityIndicator.stopAnimating()
        self.companyNameLabel.text = companyName
        self.companySymbolLabel.text = symbol
        self.priceLabel.text = "\(price)"
        self.priceChangeLabel.text = "\(priceChange)"
        
        if priceChange > 0 {
            priceChangeLabel.textColor = UIColor.green
        } else if priceChange < 0 {
            priceChangeLabel.textColor = UIColor.red
        } else {
            priceChangeLabel.textColor = UIColor.black
        }
    }
    
    private func requestLogoUrlQuote(for symbol: String){
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?&token=pk_fafd02eea972436fb8e1548832f7da0d")!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            data, response, error in
                guard
                    error == nil,
                    (response as? HTTPURLResponse)?.statusCode == 200,
                    let data = data
                else {
                    print("Network error")
                    return
                }
            
            self.parseLogoUrlQuote(url: data)
        }
        
        dataTask.resume()
    }
    
    private func parseLogoUrlQuote(url: Data){
        do{
            let jsonObject = try JSONSerialization.jsonObject(with: url)
            
            guard
                let json = jsonObject as? [String: Any],
                let logoUrl = json["url"] as? String
            else{
                print("Invalid JSON format")
                return
            }
            
            self.requestLogoQuote(for: logoUrl)
            
        } catch{
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func requestLogoQuote(for urlstr: String){
        if urlstr == "" {
            DispatchQueue.main.async{
                self.logoImage.image = nil}
            return
        }
        let url = URL(string: urlstr)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            data, response, error in
                guard
                    error == nil,
                    (response as? HTTPURLResponse)?.statusCode == 200,
                    let data = data
                else {
                    print("Network error")
                    return
                }
            
            self.parseLogoQuote(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseLogoQuote(data: Data){
        DispatchQueue.main.async{
            self.logoImage.image = UIImage(data: data)}
    }
}

struct Company: Codable {
    var companyName: String
    var symbol: String
}

