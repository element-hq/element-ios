// Made With Flow.
//
// DO NOT MODIFY, your changes will be lost when this file is regenerated.
//

import UIKit

public class ElementViewController: UIViewController {
    @IBOutlet public weak var element: ElementView!
    public var timeline: Timeline_1!

    public override func viewDidLoad() {
        super.viewDidLoad()
        timeline = Timeline_1(view: element, duration: 2)

        timeline.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + timeline.duration) {
            self.showStartViewController()
        }
    }

    private func showStartViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let startViewController = storyboard.instantiateViewController(withIdentifier: "StartViewController")
        startViewController.modalPresentationStyle = .custom
        startViewController.modalTransitionStyle = .crossDissolve
        present(startViewController, animated: true, completion: nil)
    }
}