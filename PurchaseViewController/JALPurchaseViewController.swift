//
//  JALPurchaseViewController.swift
//  PurchaseViewController
//
//  Created by Jason Lew on 7/15/15.
//  Copyright (c) 2015 Jason Lew. All rights reserved.
//

import UIKit
import StoreKit

class InAppPurchaseViewController: UIViewController, SKProductsRequestDelegate,
SKPaymentTransactionObserver {
    
    var product: SKProduct?
    var productID = "YourProductID"
    
    var activityIndicator:UIActivityIndicatorView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    let kDidPurchaseUpgradeKey = "didPurchaseUpgrade"
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restorePurchaseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        // Buttons will be enabled if product is successfully found
        buyButton.enabled = false
        restorePurchaseButton.enabled = false
        getProductInfo()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Remember to remove the transaction observer, otherwise...crash
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        // Add a translucent dark gray background around the indicator
        activityIndicator.backgroundColor = UIColor(white: 0.3, alpha: 0.4)
        activityIndicator.frame = CGRectInset(activityIndicator.frame, -8, -8)
        activityIndicator.layer.cornerRadius = activityIndicator.frame.size.height/4.0
        activityIndicator.clipsToBounds = true
        activityIndicator.center = view.center
        activityIndicator.hidden = true
        view.addSubview(activityIndicator)
    }
    
    func startActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
    }
    
    // MARK: - Setup alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        let ok = UIAlertAction(
            title: "Ok",
            style: .Default,
            handler: nil)
        alert.addAction(ok)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - StoreKit and Purchasing
    func getProductInfo() {
        startActivityIndicator()
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: NSSet(objects: self.productID) as Set<NSObject>)
            request.delegate = self
            request.start()
        } else {
            let errorText = "Please enable In App Purchasing in Settings"
            showAlert("Error", message: errorText)
        }
    }
    
    func updatePriceForLocale() {
        let currencyFormatter = NSNumberFormatter()
        currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        if let currentProduct = product {
            currencyFormatter.locale = currentProduct.priceLocale
            let priceText = currencyFormatter.stringFromNumber(currentProduct.price)
            buyButton.setTitle(priceText, forState: .Normal)
        }
    }
    
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        let products = response.products
        
        if (products.count != 0) {
            product = products[0] as? SKProduct
            if (product?.productIdentifier == self.productID) {
                buyButton.enabled = true
                restorePurchaseButton.enabled = true
                // Show the price in the user's locale
                updatePriceForLocale()
            }
        } else {
            let errorText = "Product not found."
            showAlert("Error", message: errorText)
        }
        // Stop the activity indicator
        activityIndicator.stopAnimating()
    }
    
    @IBAction func buyProduct(sender: AnyObject) {
        // Hook up your "buy" button to this function
        
        if (product != nil) {
            startActivityIndicator()
            let payment = SKPayment(product: product)
            SKPaymentQueue.defaultQueue().addPayment(payment)
        } else {
            let errorText =  "Cannot send payment request, please try again."
            showAlert("Error", message: errorText)
            activityIndicator.stopAnimating()
        }
    }
    
    func paymentQueue(queue:SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        
        for transaction in transactions as! [SKPaymentTransaction] {
            switch transaction.transactionState {
            case SKPaymentTransactionState.Purchased:
                //println("Product purchased")
                self.unlockFeature()
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            case SKPaymentTransactionState.Failed:
                // This will also be the case if the user cancels the purchase
                let errorText = "The upgrade was not purchased."
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                showAlert("No Purchase Made", message: errorText)
            case SKPaymentTransactionState.Restored:
                //println("Product restored")
                self.unlockFeature()
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            default:
                break
            }
        }
        activityIndicator.stopAnimating()
    }
    
    func unlockFeature() {
        // Save to keychain or NSUserDefaults
        
        showAlert("YourAppName Pro", message: "Upgrade successful.")
    }
    
    // MARK: - Restore purchase
    @IBAction func restorePurchase(sender: AnyObject) {
        // Hook up a button to restore purchases
        
        if (product != nil) {
            startActivityIndicator()
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue!) {
        if (true /* Check for upgrade key */) {
            //println("restore completed transactions finished")
        } else {
            showAlert("Could not restore", message: "Sorry, no previous purchases could be restored.")
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue!, restoreCompletedTransactionsFailedWithError error: NSError!) {
        showAlert("Please try again.", message: "The transaction was cancelled")
    }
}