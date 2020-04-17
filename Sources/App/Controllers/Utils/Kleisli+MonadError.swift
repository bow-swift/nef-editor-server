import Foundation
import Bow
import BowEffects

extension Kleisli {
    
    func flatMapError<E: Swift.Error, EE: Swift.Error>(_ fe: @escaping (E) -> EnvIO<D, EE, A>) -> EnvIO<D, EE, A> where F == IOPartial<E> {
        foldM({ (e: E) in .pure(Either<E, A>.left(e))^  },
              { (a: A) in .pure(Either<E, A>.right(a))^ })
            .mapError { e in e as! EE }^ // imposible case: to make compiler happy
            .flatMap { either in
                either.fold(fe, EnvIO.pure)
            }^
    }
}
