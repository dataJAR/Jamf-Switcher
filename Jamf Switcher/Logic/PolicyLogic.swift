//
//  PolicyLogic.swift
//  Jamf Switcher
//
//  Created by David Norris on 23/05/2022.
//  Copyright © 2022 dataJAR. All rights reserved.
//

import Foundation
import Cocoa

public class PolicyLogic {
    
    public let jamfLogic = JamfLogic()
    
    public func retrieveFoundPolicy(myPolices: Policies, policyToFind: String) -> [Policy] {
        let foundPolices = myPolices.policies.filter{$0.name.lowercased().contains(policyToFind.lowercased())}
        //print(foundPolices)
        return foundPolices
    }
    
    public func retrieveFoundPolicyFormatted(foundPolices: [Policy]) -> String {
        var foundPolicesFormated = ""
        for policy in foundPolices {
            foundPolicesFormated = foundPolicesFormated + policy.name + "\r"
        }
        return foundPolicesFormated
    }
    
    public func processPolicy(foundPolicies: Policies, policyToFind: String, checkedJSSURL: String, apiKey: String, flushPolicies: Bool, instanceName: String, completion: @escaping(Result<[String], JamfError>) -> Void) {
        let foundPolices = retrieveFoundPolicy(myPolices: foundPolicies, policyToFind: policyToFind)
        let foundPolicesFormated = retrieveFoundPolicyFormatted(foundPolices: foundPolices)
        var policyReport = [String]()
        let dispatchGroup = DispatchGroup()

        if foundPolices.count > 0 {
//            print("FoundPolicies - \(foundPolices.count)")
//            print(foundPolicies)
            for policy in foundPolices {
                dispatchGroup.enter()
                jamfLogic.findPolicyById(policyId: policy.id, jamfServerURL: checkedJSSURL, apiKey: apiKey, flushPolicies: flushPolicies) { result in
                    switch result {
                        
                    case .success(let foundPolicy):
                        if (flushPolicies && foundPolicy.policy.general.enabled){
                            policyReport.append("\"\(instanceName)\"" + "," + checkedJSSURL + "," + "\"\(policy.name)\"" + "," + "Flushed")
                            dispatchGroup.leave()
                        } else {
                            policyReport.append("\"\(instanceName)\"" + "," + checkedJSSURL + "," + "\"\(policy.name)\"" + "," + "\"\(PolicyCheck(foundPolicy.policy.general.enabled))\"")
                            dispatchGroup.leave()
                        }
                        
                    case .failure( _):
                        policyReport.append("\"\(instanceName)\"" + "," + checkedJSSURL + "," + "\"\(policy.name)\"" + ", N/A")
                        dispatchGroup.leave()
                    }
                }
            }
        } else {
            policyReport.append("\"\(instanceName)\"" + "," + checkedJSSURL + ", Not Found , N/A")
        }
        dispatchGroup.notify(queue: .main) {
            completion(.success(policyReport))
        }
    }
}


private func PolicyCheck(_ policy: Bool) -> String {
    if policy {
        return "Enabled"
    } else {
        return "Disabled"
    }
}
