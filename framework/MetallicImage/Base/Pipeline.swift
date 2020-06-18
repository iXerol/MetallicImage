import Dispatch

public protocol ImageSource {
    var targets: TargetContainer { get }
    func transmitPreviousImage(to target: ImageConsumer, completion: ((Bool) -> Void)?)
}

extension ImageSource {
    public func addTarget(_ target: ImageConsumer) {
        targets.append(target)
    }

    func updateTargets(with texture: Texture) {
        for target in targets {
            target.newTexture(texture)
        }
    }

    public func removeAllTargets() {
        targets.removeAll()
    }

    public func removeLastTarget() {
        targets.removeLast()
    }

    public func removeFirstTarget() {
        targets.removeFirst()
    }
}

public protocol ImageConsumer: class {
    func newTexture(_ texture: Texture)
}

public protocol ImageFilter: ImageConsumer, ImageSource {}

precedencegroup ProcessingOperationPrecedence {
    associativity: left
    higherThan: NilCoalescingPrecedence
}

infix operator =>: ProcessingOperationPrecedence

@discardableResult public func => <T: ImageConsumer>(source: ImageSource, destination: T) -> T {
    source.addTarget(destination)
    return destination
}

public class TargetContainer: Sequence {
    internal var targets: [WeakImageConsumer] = []
    public var count: Int {
        return targets.count
    }

    internal let dispatchQueue = DispatchQueue(label: "com.MetallicImage.TargetContainerQueue")

    public init() {}

    public func append(_ target: ImageConsumer) {
        dispatchQueue.async {
            let weakTarget = WeakImageConsumer(value: target)
            self.targets.append(weakTarget)
        }
    }

    public func append(contentsOf targets: TargetContainer) {
        for target in targets {
            append(target)
        }
    }

    public func makeIterator() -> AnyIterator<ImageConsumer> {
        var index = 0

        return AnyIterator { () -> ImageConsumer? in
            return self.dispatchQueue.sync{
                if (index >= self.targets.count) {
                    return nil
                }

                while self.targets[index].value == nil {
                    self.targets.remove(at: index)
                    if index >= self.targets.count {
                        return nil
                    }
                }
                index += 1
                return self.targets[index - 1].value!
            }
        }
    }

    public func removeAll() {
        dispatchQueue.async {
            self.targets.removeAll()
        }
    }

    public func removeLast() {
        dispatchQueue.async {
            self.targets.removeLast()
        }
    }

    public func removeFirst() {
        dispatchQueue.async {
            self.targets.removeFirst()
        }
    }
}

class WeakImageConsumer {
    internal weak var value: ImageConsumer?

    internal init(value: ImageConsumer) {
        self.value = value
    }
}
